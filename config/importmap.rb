# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "d3-force", to: "https://esm.sh/d3-force@3?bundle"
pin "d3-selection", to: "https://esm.sh/d3-selection@3?bundle"
