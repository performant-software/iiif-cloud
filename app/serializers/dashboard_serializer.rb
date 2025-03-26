class DashboardSerializer
  def heap(info)
    {
      used: info.dig(:vm, :usedHeapBytes),
      max: info.dig(:vm, :maxHeapBytes)
    }
  end

  def status(color, info)
    {
      application: {
        name: I18n.t('dashboard_serializer.application_name'),
        version: info.dig(:application, :version)
      },
      vm: {
        name: info.dig(:vm, :name),
        version: info.dig(:vm, :version)
      },
      os: {
        name: info.dig(:vm, :vendor),
        processors: info.dig(:vm, :numProcessors)
      },
      status_color: color
    }
  end
end