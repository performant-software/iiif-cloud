class JobItem < ApplicationRecord
  STATUS_COMPLETED = 'completed'
  STATUS_FAILED = 'failed'

  # Relationships
  belongs_to :job
  belongs_to :resource, optional: true

  # Validations
  validates :resource_id, uniqueness: { scope: :job_id }

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
