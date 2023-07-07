# frozen_string_literal: true

require 'logger'

module HelperMethods
  def spec_logger
    @spec_logger_cache ||= Logger.new($stdout).tap { |logr| logr.level = Logger::WARN }
  end

  def fixture_path
    "#{SPEC_PATH}/fixtures"
  end

  def fixture_file(path, read: true)
    path = File.join(fixture_path, path) if path.is_a?(Array)
    file = File.expand_path(path)
    return File.read(file) if read

    Pathname.new(file)
  end

  def read_json(name, path = nil)
    JSON.parse(fixture_file(name, path))
  end
end
