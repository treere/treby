defmodule TrebyWeb.CandidatePortalLive.Verify do
  use TrebyWeb, :live_view

  alias Treby.Tenants

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    tenant = Tenants.get_tenant_by_slug!(slug)
    email = session["otp_email"]

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:email, email)
     |> assign(:has_email?, is_binary(email))
     |> assign(:page_title, gettext("Enter your code"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-zinc-50 dark:bg-zinc-800 px-4">
      <div class="max-w-md w-full">
        <.card class="shadow-sm">
          <div class="text-center mb-6">
            <h2 class="text-3xl font-bold text-zinc-900 dark:text-zinc-100">
              Enter your login code
            </h2>

            <%= if @has_email? do %>
              <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
                We sent a 6-digit code to {@email}
              </p>
            <% else %>
              <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
                Enter your email to receive a login code
              </p>
            <% end %>
          </div>

          <%= if @has_email? do %>
            <.form
              for={%{}}
              action={~p"/#{@tenant.slug}/portal/verify"}
              method="post"
              class="space-y-6"
            >
              <div>
                <label for="code" class="sr-only">{gettext("Login code")}</label>
                <input
                  id="code"
                  name="code"
                  type="text"
                  inputmode="numeric"
                  maxlength="6"
                  pattern="\d{6}"
                  autocomplete="one-time-code"
                  required
                  class="input w-full text-center text-lg tracking-widest"
                  placeholder="000000"
                />
              </div>

              <div>
                <.button type="submit" variant="primary" class="w-full min-h-[44px]">
                  Verify code
                </.button>
              </div>
            </.form>

            <p class="mt-4 text-center text-xs text-zinc-400 dark:text-zinc-500">
              {gettext("Code valid 10 minutes — check spam folder, sender noreply@treby.app.")}
            </p>
            <p class="mt-1 text-center text-xs text-zinc-400 dark:text-zinc-500">
              {gettext("Didn't receive it? Check spam or correct your email.")}
              <.link
                navigate={~p"/#{@tenant.slug}/portal/login"}
                class="text-primary hover:underline ml-1"
              >
                {gettext("Correct email")}
              </.link>
            </p>
            <p class="mt-2 text-center text-xs text-zinc-400 dark:text-zinc-500">
              {gettext("You can request a new code after 60 seconds.")}
            </p>

            <.form
              for={%{}}
              action={~p"/#{@tenant.slug}/portal/login"}
              method="post"
              class="text-center mt-4"
            >
              <input type="hidden" name="email" value={@email} />
              <.button
                type="submit"
                id="resend-code-btn"
                variant="ghost"
                phx-hook=".ResendCountdown"
                data-countdown="60"
                class="text-sm min-h-[44px] px-4 disabled:opacity-50"
              >
                Resend code
              </.button>
            </.form>
            <script :type={Phoenix.LiveView.ColocatedHook} name=".ResendCountdown">
              export default {
                mounted() {
                  const btn = this.el
                  let remaining = parseInt(btn.dataset.countdown || "60", 10)
                  btn.disabled = true
                  const original = btn.textContent.trim()
                  const tick = () => {
                    if (remaining <= 0) {
                      btn.disabled = false
                      btn.textContent = original
                      clearInterval(timer)
                    } else {
                      btn.textContent = `Resend in ${remaining}s`
                      remaining -= 1
                    }
                  }
                  tick()
                  const timer = setInterval(tick, 1000)
                  this._timer = timer
                },
                destroyed() {
                  if (this._timer) clearInterval(this._timer)
                }
              }
            </script>
          <% else %>
            <.form
              for={%{}}
              action={~p"/#{@tenant.slug}/portal/login"}
              method="post"
              class="space-y-6"
            >
              <div>
                <label for="email" class="sr-only">{gettext("Email address")}</label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  required
                  class="input w-full"
                  placeholder={gettext("Email address")}
                />
              </div>

              <div>
                <.button type="submit" variant="primary" class="w-full min-h-[44px]">
                  Send login code
                </.button>
              </div>
            </.form>
            <p class="mt-4 text-center text-xs text-zinc-400 dark:text-zinc-500">
              {gettext(
                "Code valid 10 minutes — check spam folder, sender noreply@treby.app. You can request a new code after 60 seconds."
              )}
            </p>
          <% end %>
        </.card>
      </div>
    </div>
    """
  end
end
