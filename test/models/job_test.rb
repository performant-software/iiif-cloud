require 'test_helper'

class JobTest < ActiveSupport::TestCase
  test 'recompute_status! reports processing while any job_items remain pending' do
    job = Job.create!(uuid: SecureRandom.uuid, status: Job::STATUS_PROCESSING)
    JobItem.enqueue!(job: job, resource_ids: [1, 2])
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)

    job.reload
    assert_equal Job::STATUS_PROCESSING, job.status
    assert_equal 1, job.completed_count
    assert_equal 0, job.failed_count
  end

  test 'recompute_status! reports completed once every job_item succeeds' do
    job = Job.create!(uuid: SecureRandom.uuid, status: Job::STATUS_PROCESSING)
    JobItem.enqueue!(job: job, resource_ids: [1, 2])
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 2, status: JobItem::STATUS_COMPLETED)

    job.reload
    assert_equal Job::STATUS_COMPLETED, job.status
  end

  test 'recompute_status! reports failed if any job_item fails once all are resolved' do
    job = Job.create!(uuid: SecureRandom.uuid, status: Job::STATUS_PROCESSING)
    JobItem.enqueue!(job: job, resource_ids: [1, 2])
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 2, status: JobItem::STATUS_FAILED, error: 'boom')

    job.reload
    assert_equal Job::STATUS_FAILED, job.status
  end

  test 'recompute_status! clears stored storage_credentials once the job reaches a final status' do
    job = Job.create!(
      uuid: SecureRandom.uuid,
      status: Job::STATUS_PROCESSING,
      extra: { 'storage_credentials' => { 'bucket' => 'b', 'access_key_id' => 'id' } }
    )
    JobItem.enqueue!(job: job, resource_ids: [1])

    job.reload
    assert_equal({ 'bucket' => 'b', 'access_key_id' => 'id' }, job.extra['storage_credentials'])

    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)

    job.reload
    assert_equal Job::STATUS_COMPLETED, job.status
    assert_nil job.extra['storage_credentials']
  end

  test 'recompute_status! preserves other extra keys when clearing storage_credentials' do
    job = Job.create!(
      uuid: SecureRandom.uuid,
      status: Job::STATUS_PROCESSING,
      extra: { 'storage_credentials' => { 'bucket' => 'b' }, 'base_url' => 'https://example.com' }
    )
    JobItem.enqueue!(job: job, resource_ids: [1])
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)

    job.reload
    assert_nil job.extra['storage_credentials']
    assert_equal 'https://example.com', job.extra['base_url']
  end

  test 'recompute_status! does not clear storage_credentials while still processing' do
    job = Job.create!(
      uuid: SecureRandom.uuid,
      status: Job::STATUS_PROCESSING,
      extra: { 'storage_credentials' => { 'bucket' => 'b' } }
    )
    JobItem.enqueue!(job: job, resource_ids: [1, 2])
    JobItem.record_outcome!(job_uuid: job.uuid, resource_id: 1, status: JobItem::STATUS_COMPLETED)

    job.reload
    assert_equal Job::STATUS_PROCESSING, job.status
    assert_equal({ 'bucket' => 'b' }, job.extra['storage_credentials'])
  end
end
