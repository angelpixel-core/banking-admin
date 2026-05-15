require "json"

module JsonFixtureHelper
  def json_fixture(path)
    fixture_path = Rails.root.join("spec/fixtures/api_payloads/#{path}.json")
    JSON.parse(File.read(fixture_path))
  end
end
