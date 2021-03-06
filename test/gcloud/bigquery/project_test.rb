# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"
require "json"

describe Gcloud::Bigquery::Project, :mock_bigquery do
  it "creates an empty dataset" do
    mock = Minitest::Mock.new
    created_dataset = create_dataset_gapi "my_dataset"
    inserted_dataset = Google::Apis::BigqueryV2::Dataset.new(
      dataset_reference: Google::Apis::BigqueryV2::DatasetReference.new(
        project_id: project, dataset_id: "my_dataset")
    )
    mock.expect :insert_dataset, created_dataset,
      [project, inserted_dataset]
    bigquery.service.mocked_service = mock

    dataset = bigquery.create_dataset "my_dataset"

    mock.verify

    dataset.must_be_kind_of Gcloud::Bigquery::Dataset
  end

  it "creates a dataset with options" do
    id = "my_dataset"
    name = "My Dataset"
    description = "This is my dataset"
    default_expiration = 999
    location = "EU"

    mock = Minitest::Mock.new
    created_dataset = create_dataset_gapi id, name, description, default_expiration, location
    inserted_dataset = Google::Apis::BigqueryV2::Dataset.new(
      dataset_reference: Google::Apis::BigqueryV2::DatasetReference.new(
        project_id: project, dataset_id: "my_dataset"),
      friendly_name: name,
      description: description,
      default_table_expiration_ms: default_expiration,
      location: location)
    mock.expect :insert_dataset, created_dataset,
      [project, inserted_dataset]
    bigquery.service.mocked_service = mock

    dataset = bigquery.create_dataset id, name: name,
                                      description: description,
                                      expiration: default_expiration,
                                      location: location

    mock.verify

    dataset.must_be_kind_of Gcloud::Bigquery::Dataset
    dataset.name.must_equal name
    dataset.description.must_equal description
    dataset.default_expiration.must_equal default_expiration
    dataset.location.must_equal location
  end

  it "creates a dataset and access rules using a block" do
    mock = Minitest::Mock.new
    filled_access = [Google::Apis::BigqueryV2::Dataset::Access.new(
      role: "WRITER", user_by_email: "writers@example.com")]
    created_dataset = create_dataset_gapi "my_dataset"
    created_dataset.access = filled_access
    inserted_dataset = Google::Apis::BigqueryV2::Dataset.new(
      dataset_reference: Google::Apis::BigqueryV2::DatasetReference.new(
        project_id: project, dataset_id: "my_dataset"),
      access: filled_access)
    mock.expect :insert_dataset, created_dataset,
      [project, inserted_dataset]
    bigquery.service.mocked_service = mock

    dataset = bigquery.create_dataset "my_dataset" do |ds|
      ds.access do |acl|
        refute acl.writer_user? "writers@example.com"
        acl.add_writer_user "writers@example.com"
        assert acl.writer_user? "writers@example.com"
      end
    end

    mock.verify

    dataset.must_be_kind_of Gcloud::Bigquery::Dataset
    dataset.access.wont_be :empty?
  end

  it "creates a dataset with options and access rules using a block" do
    id = "my_dataset"
    name = "My Dataset"
    description = "This is my dataset"
    default_expiration = 999
    location = "EU"

    mock = Minitest::Mock.new
    filled_access = [Google::Apis::BigqueryV2::Dataset::Access.new(
      role: "WRITER", user_by_email: "writers@example.com")]
    created_dataset = create_dataset_gapi id, name, description, default_expiration, location
    created_dataset.access = filled_access
    inserted_dataset = Google::Apis::BigqueryV2::Dataset.new(
      dataset_reference: Google::Apis::BigqueryV2::DatasetReference.new(
        project_id: project, dataset_id: "my_dataset"),
      friendly_name: name,
      description: description,
      default_table_expiration_ms: default_expiration,
      location: location,
      access: filled_access)
    mock.expect :insert_dataset, created_dataset,
      [project, inserted_dataset]
    bigquery.service.mocked_service = mock

    dataset = bigquery.create_dataset "my_dataset", location: location do |ds|
      ds.name = name
      ds.description = description
      ds.default_expiration = default_expiration
      ds.access do |acl|
        refute acl.writer_user? "writers@example.com"
        acl.add_writer_user "writers@example.com"
        assert acl.writer_user? "writers@example.com"
      end
    end

    mock.verify

    dataset.must_be_kind_of Gcloud::Bigquery::Dataset
    dataset.name.must_equal name
    dataset.description.must_equal description
    dataset.default_expiration.must_equal default_expiration
    dataset.location.must_equal location
    dataset.access.wont_be :empty?
  end

  it "creates a dataset with block options and access rules not using a block" do
    id = "my_dataset"
    name = "My Dataset"
    description = "This is my dataset"
    default_expiration = 999
    location = "EU"

    mock = Minitest::Mock.new
    filled_access = [Google::Apis::BigqueryV2::Dataset::Access.new(
      role: "WRITER", user_by_email: "writers@example.com")]
    created_dataset = create_dataset_gapi id, name, description, default_expiration, location
    created_dataset.access = filled_access
    inserted_dataset = Google::Apis::BigqueryV2::Dataset.new(
      dataset_reference: Google::Apis::BigqueryV2::DatasetReference.new(
        project_id: project, dataset_id: "my_dataset"),
      friendly_name: name,
      description: description,
      default_table_expiration_ms: default_expiration,
      location: location,
      access: filled_access)
    mock.expect :insert_dataset, created_dataset,
      [project, inserted_dataset]
    bigquery.service.mocked_service = mock

    dataset = bigquery.create_dataset "my_dataset", location: location do |ds|
      ds.name = name
      ds.description = description
      ds.default_expiration = default_expiration
      ds.access.add_writer_user "writers@example.com"
    end

    mock.verify

    dataset.must_be_kind_of Gcloud::Bigquery::Dataset
    dataset.name.must_equal name
    dataset.description.must_equal description
    dataset.default_expiration.must_equal default_expiration
    dataset.location.must_equal location
    dataset.access.wont_be :empty?
  end

  it "raises when creating a dataset with a blank id" do
    stub = Object.new
    def stub.insert_dataset *args
      raise Google::Apis::ClientError.new("invalid", status_code: 409)
    end
    bigquery.service.mocked_service = stub

    # it would be really great if the error handling would differentiate
    # between AlreadyExistsError and InvalidArgumentError
    expect { bigquery.create_dataset "" }.must_raise Gcloud::AlreadyExistsError
  end

  it "lists datasets" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3),
      [project, all: nil, max_results: nil, page_token: nil]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets

    mock.verify

    datasets.size.must_equal 3
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
  end

  it "paginates datasets with all set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: true, max_results: nil, page_token: nil]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets all: true

    mock.verify

    datasets.count.must_equal 3
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    datasets.token.wont_be :nil?
    datasets.token.must_equal "next_page_token"
  end

  it "paginates datasets with max set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: 3, page_token: nil]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets max: 3

    mock.verify

    datasets.count.must_equal 3
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    datasets.token.wont_be :nil?
    datasets.token.must_equal "next_page_token"
  end

  it "paginates datasets" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: nil, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    first_datasets = bigquery.datasets
    second_datasets = bigquery.datasets token: first_datasets.token

    mock.verify

    first_datasets.count.must_equal 3
    first_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    first_datasets.token.wont_be :nil?
    first_datasets.token.must_equal "next_page_token"

    second_datasets.count.must_equal 2
    second_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    second_datasets.token.must_be :nil?
  end

  it "paginates datasets with next? and next" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: nil, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    first_datasets = bigquery.datasets
    second_datasets = first_datasets.next

    mock.verify

    first_datasets.count.must_equal 3
    first_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    first_datasets.next?.must_equal true

    second_datasets.count.must_equal 2
    second_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    second_datasets.next?.must_equal false
  end

  it "paginates datasets with next? and next with all/hidden set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: true, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: true, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    first_datasets = bigquery.datasets all: true
    second_datasets = first_datasets.next

    mock.verify

    first_datasets.count.must_equal 3
    first_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    first_datasets.next?.must_equal true

    second_datasets.count.must_equal 2
    second_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    second_datasets.next?.must_equal false
  end

  it "paginates datasets with next? and next with max set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: 3, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: nil, max_results: 3, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    first_datasets = bigquery.datasets max: 3
    second_datasets = first_datasets.next

    mock.verify

    first_datasets.count.must_equal 3
    first_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    first_datasets.next?.must_equal true

    second_datasets.count.must_equal 2
    second_datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
    second_datasets.next?.must_equal false
  end

  it "paginates datasets with all" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: nil, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets.all.to_a

    mock.verify

    datasets.count.must_equal 5
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
  end

  it "paginates datasets with all with all/hidden set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: true, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: true, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets(all: true).all.to_a

    mock.verify

    datasets.count.must_equal 5
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
  end

  it "paginates datasets with all with max set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: 3, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(2),
      [project, all: nil, max_results: 3, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets(max: 3).all.to_a

    mock.verify

    datasets.count.must_equal 5
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
  end

  it "iterates datasets with all using Enumerator" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(3, "second_page_token"),
      [project, all: nil, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets.all.take(5)

    mock.verify

    datasets.count.must_equal 5
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
  end

  it "iterates datasets with all with request_limit set" do
    mock = Minitest::Mock.new
    mock.expect :list_datasets, list_datasets_gapi(3, "next_page_token"),
      [project, all: nil, max_results: nil, page_token: nil]
    mock.expect :list_datasets, list_datasets_gapi(3, "second_page_token"),
      [project, all: nil, max_results: nil, page_token: "next_page_token"]
    bigquery.service.mocked_service = mock

    datasets = bigquery.datasets.all(request_limit: 1).to_a

    mock.verify

    datasets.count.must_equal 6
    datasets.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Dataset }
  end

  it "finds a dataset" do
    dataset_id = "found_dataset"
    dataset_name = "Found Dataset"

    mock = Minitest::Mock.new
    mock.expect :get_dataset, find_dataset_gapi(dataset_id, dataset_name),
      [project, dataset_id]
    bigquery.service.mocked_service = mock

    dataset = bigquery.dataset dataset_id

    mock.verify

    dataset.must_be_kind_of Gcloud::Bigquery::Dataset
    dataset.dataset_id.must_equal dataset_id
    dataset.name.must_equal dataset_name
  end

  it "lists jobs" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs

    mock.verify

    jobs.size.must_equal 3
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
  end

  it "lists jobs with max set" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: 3, page_token: nil, projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs max: 3

    mock.verify

    jobs.count.must_equal 3
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    jobs.token.wont_be :nil?
    jobs.token.must_equal "next_page_token"
  end

  it "lists jobs with filter set" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: "running"]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs filter: "running"

    mock.verify

    jobs.count.must_equal 3
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    jobs.token.wont_be :nil?
    jobs.token.must_equal "next_page_token"
  end

  it "paginates jobs" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: nil]
    mock.expect :list_jobs, list_jobs_gapi(2),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    first_jobs = bigquery.jobs
    second_jobs = bigquery.jobs token: first_jobs.token

    mock.verify

    first_jobs.count.must_equal 3
    first_jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    first_jobs.token.wont_be :nil?
    first_jobs.token.must_equal "next_page_token"

    second_jobs.count.must_equal 2
    second_jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    second_jobs.token.must_be :nil?
  end

  it "paginates jobs using next? and next" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: nil]
    mock.expect :list_jobs, list_jobs_gapi(2),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    first_jobs = bigquery.jobs
    second_jobs = first_jobs.next

    mock.verify

    first_jobs.count.must_equal 3
    first_jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    first_jobs.next?.must_equal true

    second_jobs.count.must_equal 2
    second_jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    second_jobs.next?.must_equal false
  end

  it "paginates jobs with next? and next and filter set" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: "running"]
    mock.expect :list_jobs, list_jobs_gapi(2),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: "running"]
    bigquery.service.mocked_service = mock

    first_jobs = bigquery.jobs filter: "running"
    second_jobs = first_jobs.next

    mock.verify

    first_jobs.count.must_equal 3
    first_jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    first_jobs.next?.must_equal true

    second_jobs.count.must_equal 2
    second_jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
    second_jobs.next?.must_equal false
  end

  it "paginates jobs with all" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: nil]
    mock.expect :list_jobs, list_jobs_gapi(2),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs.all.to_a

    mock.verify

    jobs.count.must_equal 5
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
  end

  it "paginates jobs with all and filter set" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: "running"]
    mock.expect :list_jobs, list_jobs_gapi(2),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: "running"]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs(filter: "running").all.to_a

    mock.verify

    jobs.count.must_equal 5
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
  end

  it "iterates jobs with all using Enumerator" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: nil]
    mock.expect :list_jobs, list_jobs_gapi(3, "second_page_token"),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs.all.take(5)

    mock.verify

    jobs.count.must_equal 5
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
  end

  it "iterates jobs with all with request_limit set" do
    mock = Minitest::Mock.new
    mock.expect :list_jobs, list_jobs_gapi(3, "next_page_token"),
      [project, all_users: nil, max_results: nil, page_token: nil, projection: "full", state_filter: nil]
    mock.expect :list_jobs, list_jobs_gapi(3, "second_page_token"),
      [project, all_users: nil, max_results: nil, page_token: "next_page_token", projection: "full", state_filter: nil]
    bigquery.service.mocked_service = mock

    jobs = bigquery.jobs.all(request_limit: 1).to_a

    mock.verify

    jobs.count.must_equal 6
    jobs.each { |ds| ds.must_be_kind_of Gcloud::Bigquery::Job }
  end

  it "finds a job" do
    job_id = "9876543210"

    mock = Minitest::Mock.new
    mock.expect :get_job, find_job_gapi(job_id),
      [project, job_id]
    bigquery.service.mocked_service = mock

    job = bigquery.job job_id

    mock.verify

    job.must_be_kind_of Gcloud::Bigquery::Job
    job.job_id.must_equal job_id
  end

  def create_dataset_gapi id, name = nil, description = nil, default_expiration = nil, location = "US"
    Google::Apis::BigqueryV2::Dataset.from_json \
      random_dataset_hash(id, name, description, default_expiration, location).to_json
  end

  def find_dataset_gapi id, name = nil, description = nil, default_expiration = nil
    Google::Apis::BigqueryV2::Dataset.from_json \
      random_dataset_hash(id, name, description, default_expiration).to_json
  end

  def list_datasets_gapi count = 2, token = nil
    datasets = count.times.map { random_dataset_small_hash }
    hash = {"kind"=>"bigquery#datasetList", "datasets"=>datasets}
    hash["nextPageToken"] = token unless token.nil?
    Google::Apis::BigqueryV2::DatasetList.from_json hash.to_json
  end

  def find_job_gapi job_id
    Google::Apis::BigqueryV2::Job.from_json random_job_hash(job_id).to_json
  end

  def list_jobs_gapi count = 2, token = nil
    hash = {
      "kind" => "bigquery#jobList",
      "etag" => "etag",
      "jobs" => count.times.map { random_job_hash }
    }
    hash["nextPageToken"] = token unless token.nil?

    Google::Apis::BigqueryV2::JobList.from_json hash.to_json
  end
end
