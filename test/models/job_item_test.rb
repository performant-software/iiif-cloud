require 'test_helper'

class JobItemTest < ActiveSupport::TestCase
  test 'enqueue! creates a pending JobItem per resource and sets total_count from job_items' do
    job = Job.create!(uuid: SecureRandom.uuid, status: Job::STATUS_PROCESSING)

    JobItem.enqueue!(job: job, resource_ids: [1, 2, 3])

    job.reload
    assert_equal 3, job.total_count
    assert_equal 3, job.job_items.where(status: JobItem::STATUS_PENDING).count
    assert_equal Job::STATUS_PROCESSING, job.status
  end

  test 'enqueue! is idempotent for resources already queued, so retrying a batch does not inflate total_count' do
    job = Job.create!(uuid: SecureRandom.uuid, status: Job::STATUS_PROCESSING)

    JobItem.enqueue!(job: job, resource_ids: [1, 2, 3])
    # Simulates a client retrying the same request (e.g. after a timeout) with the same resources.
    JobItem.enqueue!(job: job, resource_ids: [1, 2, 3])

    job.reload
    assert_equal 3, job.total_count
    assert_equal 3, job.job_items.count
  end

  test 'enqueue! does not disturb already-completed items when called again with an overlapping batch' do
    job = Job.create!(uuid: SecureRandom.uuid, status: Job::STATUS_PROCESSING)
    JobItem.enqueue!(job: job, resource_ids: [1, 2])
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)

    # A second batch re-sends resource 1 (already completed) alongside a genuinely new resource 3.
    JobItem.enqueue!(job: job, resource_ids: [1, 3])

    job.reload
    assert_equal 3, job.total_count
    assert_equal JobItem::STATUS_COMPLETED, job.job_items.find_by(resource_id: 1).status
    assert_equal JobItem::STATUS_PENDING, job.job_items.find_by(resource_id: 3).status
    # The previously-completed resource being re-counted as part of a larger total reopens the job.
    assert_equal Job::STATUS_PROCESSING, job.status
  end

  test 'record_outcome! is a no-op for an unknown job_uuid' do
    assert_nothing_raised do
      JobItem.record_outcome!(job_uuid: 'no-such-job', resource_id: 1, status: JobItem::STATUS_COMPLETED)
    end

    assert_equal 0, JobItem.where(resource_id: 1).count
  end
end
