class Job < ApplicationRecord
  STATUS_PENDING = 'pending'
  STATUS_PROCESSING = 'processing'
  STATUS_COMPLETED = 'completed'
  STATUS_FAILED = 'failed'

  FINAL_STATUSES = [STATUS_COMPLETED, STATUS_FAILED].freeze

  # Relationships
  has_many :job_items, dependent: :destroy
  belongs_to :user, optional: true

  # Validations
  validates :uuid, presence: true, uniqueness: true

  # Recalculates total_count/completed_count/failed_count from the job_items rows (the source of
  # truth) and derives the overall status. Safe to call concurrently from multiple workers
  # finishing at the same time - each call simply re-reads the current truth and writes a fresh
  # snapshot.
  #
  # total_count is derived here (rather than incremented separately, e.g. by a caller each time it
  # enqueues a batch) specifically so that re-sending the same batch under the same job_uuid - say,
  # after a client-side timeout retry - can't inflate it: JobItem.enqueue! upserts one pending row
  # per resource, so a repeated resource is simply left alone rather than counted twice, which
  # previously could leave a job stuck in "processing" forever (its total_count permanently ahead
  # of how many distinct resources could ever actually complete).
  def recompute_status!
    with_lock do
      total = job_items.count
      counts = job_items.group(:status).count
      completed = counts[JobItem::STATUS_COMPLETED] || 0
      failed = counts[JobItem::STATUS_FAILED] || 0

      new_status = if total.positive? && (completed + failed) >= total
                     failed.positive? ? STATUS_FAILED : STATUS_COMPLETED
                   else
                     STATUS_PROCESSING
                   end

      attributes = { total_count: total, completed_count: completed, failed_count: failed, status: new_status }
      # Credentials are only needed while resources are actively being processed under this job;
      # once it reaches a final status there's nothing left to authenticate, so there's no reason
      # to keep them sitting in this jsonb column as plaintext any longer than necessary.
      attributes[:extra] = extra.except('storage_credentials') if FINAL_STATUSES.include?(new_status)

      update!(attributes)
    end
  end
end
