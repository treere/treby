defmodule Treby.SchedulingEmailTest do
  use ExUnit.Case, async: true

  alias Treby.SchedulingEmail

  test "booking_link_candidate/4 builds email with subject, recipient, and booking link" do
    candidate = %{name: "Jane Doe", email: "jane@example.com"}
    job = %{title: "Software Engineer"}
    tenant = %{name: "Acme Corp"}
    link = "https://example.com/acme/schedule/abc123"

    email = SchedulingEmail.booking_link_candidate(candidate, job, tenant, link)

    assert email.subject == "Book your interview - Software Engineer"
    assert email.to == [{"", "jane@example.com"}]

    html = email.html_body
    assert html =~ "https://example.com/acme/schedule/abc123"
    assert html =~ "Acme Corp"

    text = email.text_body
    assert text =~ "https://example.com/acme/schedule/abc123"
    assert text =~ "Software Engineer"
  end
end
