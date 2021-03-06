# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a extract of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"

describe Gcloud::Bigquery::Dataset, :query, :mock_bigquery do
  let(:query) { "SELECT name, age, score, active FROM [some_project:some_dataset.users]" }
  let(:dataset_id) { "my_dataset" }
  let(:dataset_gapi) { random_dataset_gapi dataset_id }
  let(:dataset) { Gcloud::Bigquery::Dataset.from_gapi dataset_gapi,
                                                      bigquery.service }

  it "queries the data with default dataset option set" do
    mock = Minitest::Mock.new
    bigquery.service.mocked_service = mock
    mock.expect :query_job, query_data_gapi, [project, query_request_gapi]

    data = dataset.query query
    data.class.must_equal Gcloud::Bigquery::QueryData
    data.count.must_equal 3
    mock.verify
  end
end
