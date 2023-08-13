# Automatically set the listening port from a file.

This plugin will check and set the listening port for your Porla sessions based on the port number read from a file.

It is useful for VPN's that don't assign static forwarded ports assign a different port on each connection.

VPN Projects such as Gluetun will write the forwarded port number to a file and this plugin will read that file and set the listening port accordingly.

The port is set when the plugin loads on porla startup as well as on a cron timer.

## Configuration

The plugin is configured with Lua. The following is an example Lua
configuration that you can adjust to your needs and then paste in the plugin
configuration field in Porla. The config is an array of tables to monitor and
update the ports of multiple sessions.

```lua
return {
  {
    cron = "0 */1 * * * *",
    path = "/var/lib/porla/port.dat",
    session_name = "default",
    listen_interface = "tun0"
  },
  {
    cron = "0 */1 * * * *",
    path = "/var/lib/porla/racingport.dat",
    session_name = "racing",
    listen_interface = "wg0",
    replace_existing = true
  },
  {
    cron = "0 */1 * * * *",
    path = "/var/lib/porla/publicport.dat",
    session_name = "public",
    listen_interface = "fe80:1234::1",
    replace_existing = true
  }
}
```

### `cron`

The cron schedule to use for checking and setting the listening port. 

Check the [porla cron documentation](https://porla.org/plugins/packages/cron) for more information.

### `path`

Path to the file containing the port number. The file should contain nothing but the port number on the first line.

### `session_name`

Name of the session whose listening port should be updated.

### `listen_interface`

Name of the interface that will be monitored and updated by the plugin. Common interface names are tun0 and wg0.

If the listen interface is an IPv6 address don't enclose it in square brackets. For example "::" instead of "[::]".

### `replace_existing`

Boolean, defaults to false. If set to true all other listening interfaces will be removed and the replaced with the listen_interface set in the plugin config.