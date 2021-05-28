# Bare Bones Stripe Application

## Stripe Charge

To use it, 

1. Set up correct STRIPE_SECRET_KEY through a shell file, where the elixir code is present.

2. Run the elixir program in the same account.

3. Create a html form and replace "data-key" field with your public key.

 and direct its output to the elixir program -

~~~~~~~~~~
<form method=POST action="/form-payment/purchase">
<input type="hidden" name="amount" value="65000">
<script src="https://checkout.stripe.com/checkout.js" class="stripe-button"
          data-key="pk_live_fjff6jDr3j$v#F##F$"
          data-amount="65000"
          data-email=""
          data-allow-remember-me="false"
          data-billing-address="true"
          data-zip-code="true"
          data-locale="auto"></script>
</form>
~~~~~~~~~~

4. Direct the output of the form correctly to  the elixir program.
That means the following line in the above form -

~~~~~~~~~~
<form method=POST action="/form-payment/purchase">
~~~~~~~~~~

matches line 16 in "lib/formplug.ex".

~~~~~~~~~~
  def route("POST", ["form-payment", "purchase"], conn) do
~~~~~~~~~~

4. Also configure nginx to ensure that all responses to the form goes to elixir program.

~~~~~~~~~
location /form-payment
{
           proxy_pass http://127.0.0.1:4000/form-payment;
           proxy_redirect off;
           proxy_set_header Host $host;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Ssl on;
}
~~~~~~~~~

### Passing Custom Data

Add them as hidden variables in the above form. When the form is submitted, they will be returned as parameters.

## Webhook

The following function addresses webhooks -

~~~~~~~~~
  def route("POST", ["form-payment", "webhook"], conn) do
    IO.inspect conn
    conn |> Plug.Conn.send_resp( 200, "Accepted")
  end
~~~~~~~~~

To test it, 

1. Run your elixir program ('mix run --no-halt'),
2. Go to Stripe online website and choose test mode,
3. Click on developers --> webhooks, add http://mycooldomain.com/form-payment/webhook and send a test webhook.

You will see the message being sent from Stripe on your elixir console. Here is a typical one (with some entries modified).

~~~~~~~~~
%Plug.Conn{
  adapter: {Plug.Adapters.Cowboy.Conn, :...},
  assigns: %{},
  before_send: [],
  body_params: %Plug.Conn.Unfetched{aspect: :body_params},
  cookies: %Plug.Conn.Unfetched{aspect: :cookies},
  halted: false,
  host: "mycooldomain.com",
  method: "POST",
  owner: #PID<0.324.0>,
  params: %Plug.Conn.Unfetched{aspect: :params},
  path_info: ["form-payment", "webhook"],
  path_params: %{},
  port: 80,
  private: %{},
  query_params: %Plug.Conn.Unfetched{aspect: :query_params},
  query_string: "",
  remote_ip: {10, 0, 0, 99},
  req_cookies: %Plug.Conn.Unfetched{aspect: :cookies},
  req_headers: [
    {"host", "mycooldomain.com"},
    {"x-forwarded-for", "54.187.174.169"},
    {"x-forwarded-ssl", "on"},
    {"connection", "close"},
    {"content-length", "754"},
    {"user-agent", "Stripe/1.0 (+https://stripe.com/docs/webhooks)"},
    {"accept", "*/*; q=0.5, application/xml"},
    {"cache-control", "no-cache"},
    {"content-type", "application/json; charset=utf-8"},
    {"stripe-signature",
     "t=1620481715,v1=a4e683e2fed4c810bbfed756c0a8e82a2911e0634963f23e077f946504f30a89,v0=f4117f1a462ddf5295b1b1a7a0c983f128b612da321bed2ffffdce24d00642f5"},
    {"accept-encoding", "gzip"}
  ],
  request_path: "/form-payment/webhook",
  resp_body: nil,
  resp_cookies: %{},
  resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}],
  scheme: :http,
  script_name: [],
  secret_key_base: nil,
  state: :unset,
  status: nil
}
~~~~~~~~~

### Security of webhooks

The webhook comes with a signature that looks like -

~~~~~~~~~
{"stripe-signature",
     "t=1620481715,v1=a4e683e2fed4c810bbfed756c0a8e82a2911e0634963f23e077f946504f30a89,v0=f4117f1a462ddf5295b1b1a7a0c983f128b612da321bed2ffffdce24d00642f5"},
~~~~~~~~~

[This section](https://stripe.com/docs/webhooks/signatures) in the Stripe manual explains how to parse and verify this signature. [This tutorial](https://connerfritz.com/blog/stripe-webhooks-in-phoenix-with-elixir-pattern-matching) explains the steps in more detail.

We implemented this in our code and you can try it out by sending test webhook from the Stripe website. 
~~~~~~~~~
    signing_secret = System.get_env("STRIPE_SIGNING_SECRET")
    {:ok, body, _} = Plug.Conn.read_body(conn)
    [stripe_signature] = Plug.Conn.get_req_header(conn, "stripe-signature")
    IO.inspect Stripe.Webhook.construct_event(body, stripe_signature, signing_secret)
~~~~~~~~~

Please note that the "STRIPE_SIGNING_SECRET" is a different key ("signing secret") available from the webhooks page, and it is not the same as the secret key that is used for payment.


## Stripe Subscription

https://stripe.com/docs/billing/subscriptions/examples

~~~~~~~~~~
<form method=POST action="/form-payment/subscribe">
<input type="hidden" name="amount" value="65000">
<script src="https://checkout.stripe.com/checkout.js" class="stripe-button"
          data-key="pk_live_fjff6jDr3j$v#F##F$"
          data-amount="65000"
          data-email=""
          data-allow-remember-me="false"
          data-billing-address="true"
          data-zip-code="true"
          data-locale="auto"></script>
</form>
~~~~~~~~~~


### Webhook Interactions

|Result   | Action                  | Event ID                     | Time                  | 
|---------|-------------------------|------------------------------|-----------------------|
| Succeeded | payment_method.attached | evt_1Ivv7KGlbTd7l4KBZXlJJdXK | May 27,  7:08 PM | 
| Succeeded | customer.card.created | evt_1Ivv7KGlbTd7l4KBWcbioJaL | May 27,  7:08 PM | 
| Succeeded | customer.created | evt_1Ivv7KGlbTd7l4KB5az89L77 | May 27,  7:08 PM | 
| Succeeded | customer.updated | evt_1Ivv7LGlbTd7l4KB5zKQYSsw | May 27,  7:08 PM | 
| Succeeded | invoice.created | evt_1Ivv7LGlbTd7l4KB70NxDrI6 | May 27,  7:08 PM | 
| Succeeded | invoice.finalized | evt_1Ivv7MGlbTd7l4KBf96SoIGr | May 27,  7:08 PM | 
| Succeeded | invoice.paid | evt_1Ivv7MGlbTd7l4KBM45tHPPL | May 27,  7:08 PM | 
| Succeeded | invoice.payment_succeeded | evt_1Ivv7MGlbTd7l4KBI3tc2Ma7 | May 27,  7:08 PM | 
| Succeeded | customer.subscription.created | evt_1Ivv7MGlbTd7l4KBr9fHrpmw | May | 27, 7:08 PM | 
| Succeeded | setup_intent.created | evt_1Ivv7MGlbTd7l4KBRdXg6Ihs | May 27,  7:08 PM | 
| Succeeded | setup_intent.succeeded | evt_1Ivv7MGlbTd7l4KBgmCkhjek | May 27, 7:08 PM | 


## Payment Intent

https://stripe.com/docs/payments/accept-a-payment?ui=elements

https://github.com/code-corps/stripity_stripe

Stripe 

https://github.com/code-corps/stripity_stripe


