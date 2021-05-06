defmodule Unsub.Email do
  import Bamboo.Email

  def welcome_email(recipient, subject, msg) do
    new_email(
      to: recipient,
      from: "mycooldomain.com",
      subject: subject,
      html_body: msg,
      text_body: msg
    )
  end
end
