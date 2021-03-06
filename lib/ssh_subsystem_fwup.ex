defmodule SSHSubsystemFwup do
  @moduledoc """
  SSH subsystem for upgrading Nerves devices

  This module provides an SSH subsystem for Erlang's `ssh` application. This
  makes it possible to send firmware updates to Nerves devices using plain old
  `ssh` like this:

  ```shell
  cat $firmware | ssh -s $ip_address fwup
  ```

  Where `$ip_address` is the IP address of your Nerves device. Depending on how
  you have Erlang's `ssh` application set up, you may need to pass more
  parameters (like username, port, identities, etc.).

  See [`nerves_ssh`](https://github.com/nerves-project/nerves_ssh/) for an easy
  way to set this up. If you don't want to use `nerves_ssh`, then in your call
  to `:ssh.daemon` add the return value from
  `SSHSubsystemFwup.subsystem_spec/1`:

  ```elixir
  devpath = Nerves.Runtime.KV.get("nerves_fw_devpath")

  :ssh.daemon([
        {:subsystems, [SSHSubsystemFwup.subsystem_spec(devpath: devpath)]}
      ])
  ```

  See `SSHSubsystemFwup.subsystem_spec/1` for options. You will almost always
  need to pass the path to the device that should be updated since that is
  device-specific.
  """

  @typedoc """
  Options:

  * `:devpath` - path for fwup to upgrade (Required)
  * `:fwup_path` - path to the fwup firmware update utility
  * `:fwup_extra_options` - additional options to pass to fwup like for setting
    public keys
  * `:success_callback` - an MFA to call when a firmware update completes
    successfully. Defaults to `{Nerves.Runtime, :reboot, []}`.
  * `:task` - the task to run in the firmware update. Defaults to `"upgrade"`
  * `:subsystem` - the ssh subsystem name. Defaults to 'fwup'
  """
  @type options :: [
          devpath: Path.t(),
          fwup_path: Path.t(),
          fwup_extra_options: [String.t()],
          task: String.t(),
          success_callback: mfa(),
          subsystem: charlist() | String.t()
        ]

  @doc """
  Return a subsystem spec for use with `ssh:daemon/[1,2,3]`
  """
  @spec subsystem_spec(options()) :: :ssh.subsystem_spec()
  def subsystem_spec(options \\ []) do
    subsystem_name = Keyword.get(options, :subsystem, 'fwup') |> to_charlist()

    {subsystem_name, {SSHSubsystemFwup.Handler, options}}
  end
end
