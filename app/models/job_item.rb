class JobItem < ApplicationRecord
  STATUS_PENDING = 'pending'
  STATUS_COMPLETED = 'completed'
  STATUS_FAILED = 'failed'

  # Relationships
  belongs_to :job
  belongs_to :resource, optional: true

  # Validations
  validates :resource_id, uniqueness: { scope: :job_id }

  # Idempotently creates a pending JobItem for each of the given resource_ids under +job+, then
  # recomputes the job's total_count/status from the result. Safe to call more than once with
  # overlapping resource_ids (e.g. a client retrying the same batch after a request timeout): the
  # unique index on (job_id, resource_id) means a resource that's already queued is simply left
  # alone (ON CONFLICT DO NOTHING via unique_by:) rather than being inserted a second time, so
  # retried batches can't inflate the job's total_count.
  def self.enqueue!(job:, resource_ids:)
    now = Time.current
    rows = resource_ids.map do |resource_id|
      { job_id: job.id, resource_id: resource_id, status: STATUS_PENDING, created_at: now, updated_at: now }
    end

    insert_all(rows, unique_by: %i(job_id resource_id)) if rows.any?

    job.recompute_status!
  end

  # Idempotently records the outcome of a single resource's processing for +job_uuid+ and
  # recomputes the parent job's aggregate status. Upserting on the (job_id, resource_id) unique
  # index means Sidekiq retries of the same resource simply overwrite the previous outcome rather
  # than double-counting it.
  def self.record_outcome!(job_uuid:, resource_id:, status:, error: nil)
    job = Job.find_by(uuid: job_uuid)
    return if job.nil?

    upsert(
      { job_id: job.id, resource_id: resource_id, status: status, error: error, updated_at: Time.current },
      unique_by: %i(job_id resource_id)
    )

    job.recompute_status!
  end
end
