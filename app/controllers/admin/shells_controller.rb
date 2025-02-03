class Admin::ShellsController < Admin::ApplicationController
  before_action :set_scooter

  def show
    @commands = [
      # Common shell commands
      { type: "shell", cmd: "uptime", desc: "Show system uptime" },
      { type: "shell", cmd: "systemctl status rescoot-radio-gaga", desc: "Service status" },
      { type: "shell", cmd: "journalctl -u rescoot-radio-gaga -n 50", desc: "Service logs" },
      # Common Redis commands
      { type: "redis", cmd: "hgetall", args: [ "vehicle" ], desc: "Get vehicle info" },
      { type: "redis", cmd: "hgetall", args: [ "system" ], desc: "Get system info" }
    ]
  end

  def execute
    command_type = params[:type]
    cmd = params[:cmd]
    args = params[:args]&.split(",") || []

    result = case command_type
    when "shell"
      ScooterCommandService.new(@scooter).send_command("shell", cmd: cmd)
    when "redis"
      ScooterCommandService.new(@scooter).send_command("redis", cmd: cmd, args: args)
    end

    Rails.logger.debug result

    if result.success?
      render turbo_stream: [
        turbo_stream.append("shell_output",
          partial: "command_entry",
          locals: {
            command: build_command_text(command_type, cmd, args),
            scooter: @scooter
          })
      ]
    else
      render turbo_stream: [
        turbo_stream.append("shell_output",
          partial: "error_message",
          locals: { error: result.error })
      ]
    end
  end

  private

  def set_scooter
    @scooter = Scooter.find(params[:scooter_id])
  end

  def build_command_text(type, cmd, args)
    case type
    when "shell"
      "$ #{cmd}"
    when "redis"
      "redis> #{cmd} #{args.join(' ')}"
    end
  end
end
