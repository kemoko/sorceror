module AsyncHelper
  def eventually(options = {})
    timeout = options[:timeout] || ENV['TIMEOUT'].try(:to_f) || 2
    interval = options[:interval] || 0.1
    time_limit = Time.now + timeout
    loop do
      begin
        val = yield
      rescue Exception => error
      end
      return if error.nil? && val
      raise error if Time.now >= time_limit
      sleep interval.to_f
    end
  end
  alias_method :wait_for, :eventually
end
