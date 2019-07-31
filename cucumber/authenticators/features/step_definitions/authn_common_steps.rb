Then(/^user "(\S+)" is authorized$/) do |username|
  expect(token_for(username, @response_body)).to be
end

Then(/it is a bad request/) do
  expect(bad_request?).to be true
end

Then(/it is unauthorized/) do
  expect(unauthorized?).to be true
end

Then(/it is forbidden/) do
  expect(forbidden?).to be true
end

Then(/it is gateway timeout/) do
  expect(gateway_timeout?).to be true
end

Then(/it is bad gateway/) do
  expect(bad_gateway?).to be true
end
