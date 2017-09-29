![logo](logo.png)

This script will send email with today's weather forecast, so you know if the weather is perhaps possible for
groundhandling at your groundhandling location. Some more links to forecasts are provided in the email.

## Dependencies

* `sendmail`
* `mongodb` (optional)

## Installation

1. Copy this script to a specified location
1. Run `bundle install`
1. Copy config.json.example to config.json
1. Get API key by registration at https://darksky.net/dev/register
1. Modify config.json and set `darksky_api_key`
1. Add cronjob `00 06 * * * /bin/ruby /path/to/fetch_forecast.rb`

## TODO

Some additional features would be nice:

- [ ] Create website, so new users can sign up and set location and notification channels by themselfs
- [ ] Add more notification channels (e.g. slack, telegram bot)

Contribution is very welcome! Create an issue or pull request!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature-[short_description]` or `git checkout -b fix-[github_issue_number]-[short_description]`)
3. Commit your changes (`git commit -am 'Add some missing feature'`)
4. Push to the branch (`git push origin [branch-name]`)
5. Create new Pull Request

## License

MIT License

Copyright (c) 2017 DSIW

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
