# Bare Bones Stripe Application


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
</form></td>
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



