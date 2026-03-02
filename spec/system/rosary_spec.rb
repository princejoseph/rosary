require "rails_helper"

RSpec.describe "Rosary app", type: :system do
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 390, 844 ]) do |opts|
      opts.add_argument("--no-sandbox")
      opts.add_argument("--disable-dev-shm-usage")
    end
  end

  it "loads and renders the header" do
    visit root_path
    expect(page).to have_css(".app-header", wait: 20)
    expect(page).to have_css(".mystery-name")
  end

  it "shows prayer content and navigation" do
    visit root_path
    expect(page).to have_css(".content", wait: 20)
    expect(page).to have_css(".nav-row")
    expect(page).to have_css(".btn-nav")
  end

  it "advances to the next step when next is clicked" do
    visit root_path
    expect(page).to have_css(".prayer-heading", wait: 20)
    initial_heading = find(".prayer-heading").text

    all(".btn-nav").last.click

    expect(page).not_to have_text(initial_heading, wait: 10)
  end

  it "language toggle switches between EN and ML" do
    visit root_path
    expect(page).to have_button("മല", wait: 20)

    click_button "മല"
    expect(page).to have_button("EN", wait: 5)

    click_button "EN"
    expect(page).to have_button("മല", wait: 5)
  end

  it "theme toggle switches between Minimal and Classic" do
    visit root_path
    expect(page).to have_button("Minimal", wait: 20)
    expect(page).to have_css(".app.classic", wait: 5)

    click_button "Minimal"
    expect(page).not_to have_css(".app.classic", wait: 5)
    expect(page).to have_button("Classic")

    click_button "Classic"
    expect(page).to have_css(".app.classic", wait: 5)
  end
end
