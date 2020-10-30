# Rudolph
[![Swift Version](https://img.shields.io/badge/Swift-5.3-orange?logo=swift)](https://swift.org)
![Heroku](https://img.shields.io/badge/Heroku-Deployed-purple?logo=heroku)
[![License](https://img.shields.io/badge/license-Apache%202.0-brightgreen.svg)](https://github.com/hackclub/Rudolph/blob/master/LICENSE)

Giving gp to Hack Clubbers who contribute to open source!

## 🏖 The flow:
 1. Post a message to scrapbook and react with the special emoji (`rudolph`)
 2. Rudolph runs some basic checks on, to make sure they aren't spam Pull Requests
 3. The total amount of gp you earn is calculated which is **15gp** plus any events that the PR is eligible for
 4. That is submitted to the review channel to be checked to see if it is a spam PR
 5. Your gp is given to you by the friendly `bankerapi` bot!

### ⚙️ Setup:
 1. Install Swift: https://swift.org/download/#releases It's available for OS X/Windows/Linux and the toolchain doesn't take up too much space.
 3. You also need to have vapor installed: `brew install vapor` on OS X, or [install it for Linux](https://docs.vapor.codes/4.0/install/linux/).
 4. To use the database, you need to also need to install postgres: `brew install postgres` and make a user called "rudolph". There's no password.
 5. Finally, you need to have the slack bot set up:
  - It needs the scopes: 
    - `channel:read`
    - `channel:history`
    - `chat:write`
    - `reactions:read`
  - Set the events api up, pointing it at `https://[YOUR SERVER].com/slack/events`
    - The only event subscription it needs is the `reactions_read.`
 6. Finally, finally, you need to fill in all the information in `.env.example`. To check that it can build, you can just fill it with nonsense, but, of course, it won't run/talk with slack.
