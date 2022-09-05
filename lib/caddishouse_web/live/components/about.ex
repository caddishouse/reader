defmodule CaddishouseWeb.Live.Components.About do
  @moduledoc false
  use CaddishouseWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-5 space-y-3">
      <div>
        <div class="block mb-1 text-sm font-semibold text-gray-700">
          About Caddishouse
        </div>
        <div class="prose">
          <p>
            Caddishouse is a document reader. It was built as a personal project to provide a better experience reading through research papers and textbooks.
          </p>
          <p>It's focused on the following:</p>
          <ul>
            <li>Picking up where you left off should be completely effortless</li>
            <li>Bouncing around the document should be seamless (TBD)</li>
            <li>Use as little bandwidth, memory and CPU as possible on the client-side (TBD)</li>
            <li><a href="https://github.com/caddishouse/www" target="_blank">Open source</a></li>
          </ul>

          <p>
            <a href="/privacy-policy">Privacy Policy</a>
            <a href="/terms">Terms of Service</a>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
