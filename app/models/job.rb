class Job < ApplicationRecord
  STATUS_PENDING = 'pending'
  STATUS_PROCESSING = 'processing'
  STATUS_COMPLETED = 'completed'
  STATUS_FAILED = 'failed'

  # Relationships
  has_many :job_items, dependent: :destroy

  # Validations
  validates :uuid, presence: true, uniqueness: true

  # Adds +count+ to total_count (e.g. when another batch of resources is enqueued under the same
  # job uuid) and recomputes status, since a growing total_count can turn a job that looked
  # "complete" back into "processing".
  def add_to_total!(count)
    increment!(:total_count, count)
    recompute_status!
  end

  # Recalculates completed_count/failed_count from the job_items rows (the source of truth) and
  # derives the overall status. Safe to call concurrently from multiple workers finishing at the
  # same time - each call simply re-reads the current truth and writes a fresh snapshot.
  def recompute_status!
    with_lock do
      counts = job_items.group(:status).count
      completed = counts[JobItem::STATUS_COMPLETED] || 0
      failed = counts[JobItem::STATUS_FAILED] || 0

      new_status = if total_count.positive? && (completed + failed) >= total_count
                     failed.positive? ? STATUS_FAILED : STATUS_COMPLETED
                   else
                     STATUS_PROCESSING
                   end

      update!(completed_count: completed, failed_count: failed, status: new_status)
    end
  end
end
