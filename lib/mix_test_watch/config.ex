defmodule MixTestWatch.Config do
  @moduledoc """
  Responsible for gathering and packaging the configuration for the task.
  """

  @default_runner MixTestWatch.PortRunner
  @default_tasks ~w(test)
  @default_clear false
  @default_timestamp false
  @default_exclude [~r/\.#/]
  @default_extra_extensions []
  @default_cli_executable "mix"


  defstruct tasks:            @default_tasks,
            clear:            @default_clear,
            timestamp:        @default_timestamp,
            runner:           @default_runner,
            exclude:          @default_exclude,
            extra_extensions: @default_extra_extensions,
            cli_executable:   @default_cli_executable,
            cli_args:         []

  @spec new([String.t]) :: %__MODULE__{}
  @doc """
  Create a new config struct, taking values from the ENV
  """
  def new(cli_args \\ []) do
    cli_config =
      cli_args
      |> OptionParser.parse!()
      |> extract_config_from_cli_args()

    cli_args = remove_watch_config(cli_args)

    %__MODULE__{
      tasks:             get_tasks(cli_config),
      clear:             get_clear(cli_config),
      timestamp:         get_timestamp(cli_config),
      runner:            get_runner(cli_config),
      exclude:           get_excluded(cli_config),
      cli_executable:    get_cli_executable(cli_config),
      cli_args:          cli_args,
      extra_extensions:  get_extra_extensions(cli_config),
    }
  end


  defp extract_config_from_cli_args({configs, _}) do
    configs
    |> Keyword.get(:"watch.config")
    |> extract_config_from_string()
  end

  defp extract_config_from_string(nil), do: %{}
  defp extract_config_from_string(other) when not is_binary(other), do: %{}
  defp extract_config_from_string(string) do
    for config <- String.split(string, ";"), into: %{} do
      case String.split(config, "=") do
        [key, value] -> {key, Poison.decode!(value)}
        [key] -> {key, true}
      end
    end
  end

  defp remove_watch_config(["--watch.config" | []]), do: []
  defp remove_watch_config(["--watch.config" | t]) do
    t
    |> hd()
    |> String.starts_with?("--")
    |> if(do: t, else: tl(t))
  end

  defp remove_watch_config([h | t]), do: [h | remove_watch_config(t)]
  defp remove_watch_config([]), do: []

  defp get_runner(%{"runner" => cli}), do: cli
  defp get_runner(_) do
    Application.get_env(:mix_test_watch, :runner, @default_runner)
  end

  defp get_tasks(%{"tasks" => cli}), do: cli
  defp get_tasks(_) do
    Application.get_env(:mix_test_watch, :tasks, @default_tasks)
  end

  defp get_clear(%{"clear" => cli}), do: cli
  defp get_clear(_) do
    Application.get_env(:mix_test_watch, :clear, @default_clear)
  end

  defp get_timestamp(%{"timestamp" => cli}), do: cli
  defp get_timestamp(_) do
    Application.get_env(:mix_test_watch, :timestamp, @default_timestamp)
  end

  defp get_excluded(%{"excluded" => cli}), do: cli
  defp get_excluded(_) do
    Application.get_env(:mix_test_watch, :exclude, @default_exclude)
  end

  defp get_cli_executable(%{"cli_executable" => cli}), do: cli
  defp get_cli_executable(_) do
    Application.get_env(:mix_test_watch, :cli_executable,
                        @default_cli_executable)
  end

  defp get_extra_extensions(%{}) do
    Application.get_env(:mix_test_watch, :extra_extensions,
                        @default_extra_extensions)
  end
end
