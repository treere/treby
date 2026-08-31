unless Code.ensure_loaded?(PhoenixStorybook.Router) do
  defmodule PhoenixStorybook.Router do
    defmacro storybook_assets do
      quote do
      end
    end

    defmacro live_storybook(_path, _opts) do
      quote do
      end
    end
  end
end

unless Code.ensure_loaded?(PhoenixStorybook) do
  defmodule PhoenixStorybook do
    defmacro __using__(_opts) do
      quote do
      end
    end

    def enabled?, do: false
  end
end
