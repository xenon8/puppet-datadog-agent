# Class: datadog_agent::installer_params
#
# This class contains the Datadog installer parameters
#

class datadog_agent::installer_params (
  String $api_key = 'your_API_key',
  String $datadog_site = 'datadoghq.com',
  String $packages_to_install = 'datadog-agent',
) {
  $role_version = load_module_metadata($module_name)['version']

  file { 'Trace payload templating':
    ensure  => file,
    path    => '/tmp/trace_payload.json',
    content => epp('datadog_agent/installer-telemetry/trace.json.epp', {
        'role_version'        => $role_version,
        'packages_to_install' => $packages_to_install
      }
    ),
  }

  file { 'Log payload templating':
    ensure  => file,
    path    => '/tmp/log_payload.json',
    content => epp('datadog_agent/installer-telemetry/log.json.epp', {
        'role_version' => $role_version
      }
    ),
  }

  file { 'Telemetry script templating':
    ensure  => file,
    path    => '/tmp/datadog_send_telemetry.sh',
    content => epp('datadog_agent/installer-telemetry/send_telemetry.sh.epp', {
        'datadog_site' => $datadog_site,
        'api_key'      => $api_key
      }
    ),
    mode    => '0744',
  }

  exec { 'Run telemetry script':
    # We don't want to fail the installation if telemetry fails and we need to proceed to cleanup step, hence || true
    command => 'bash /tmp/datadog_send_telemetry.sh || true',
    path    => ['/usr/bin', '/bin'],
    require => [
      File['Trace payload templating'],
      File['Log payload templating'],
    ],
  }

  # Clean up telemetry script as it contains API key in clear text
  # Other files will be cleaned up automatically as part of /tmp cleanup
  file { 'Remove telemetry script':
    ensure  => absent,
    path    => '/tmp/datadog_send_telemetry.sh',
    require => Exec['Run telemetry script'],
  }
}
