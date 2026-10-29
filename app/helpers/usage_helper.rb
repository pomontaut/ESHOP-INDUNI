module UsageHelper
  def usage_duration(seconds)
    return "—" if seconds.nil?
    s = seconds.to_i
    s < 60 ? "#{s} s" : "#{s / 60} min #{format('%02d', s % 60)}"
  end
end
