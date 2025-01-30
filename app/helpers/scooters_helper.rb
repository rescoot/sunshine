module ScootersHelper
  def battery_status_classes(level)
    return "bg-gray-50 text-gray-600 ring-gray-500/10" if level.nil?

    case level
    when 0..20
      "bg-red-50 text-red-700 ring-red-600/20"
    when 21..40
      "bg-orange-50 text-orange-700 ring-orange-600/20"
    when 41..60
      "bg-yellow-50 text-yellow-700 ring-yellow-600/20"
    else
      "bg-green-50 text-green-700 ring-green-600/20"
    end
  end
end
