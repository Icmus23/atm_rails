# ATM API

## Installation guide

- clone the repo
- go to cloned atm_rails folder
- run ```bundle install```
- run ```rails db:create```
- run ```rails db:migrate```
- run ```rails db:seed```
- run ```rails s```
- optionally run ```rspec``` to check tests
- to test API try next requests
```
    # request to add money to ATM
    PUT /api/v1/atms/1/add_banknotes, params: {
        banknotes: { '5': 3, '10': 4, '25': 5, '50': 6 }
    }

    # request to withdraw money from ATM
    PUT /api/v1/atms/1/add_withdraw_banknotes, params: { amount: 100 }
