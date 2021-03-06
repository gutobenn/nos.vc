# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "Explore projects Feature" do

  before(:each) do

    #Categories
    category_1 = Factory(:category, :featured => true)
    category_2 = Factory(:category, :featured => true)

    # Recommended projects (some of them expired)
    10.times do
      Factory(:project, created_at: 30.days.ago, expires_at: 30.days.from_now, visible: true, recommended: true, category: category_1)
    end
    5.times do
      Factory(:project, created_at: 30.days.ago, expires_at: 10.days.ago, visible: true, recommended: true, category: category_1, name: "Weird name")
    end

    # Expiring projects
    for days in 1..10 do
      Factory(:project, created_at: 30.days.ago, expires_at: days.days.from_now, visible: true, recommended: false, category: category_1)
    end

    # Recent projects
    for days in 1..10 do
      Factory(:project, created_at: days.days.ago, expires_at: 30.days.from_now, visible: true, recommended: false, category: category_2)
    end

    # Successful projects
    for days in 1..10 do
      project = Factory(:project, created_at: 30.days.ago, expires_at: days.days.ago, visible: true, recommended: false, category: category_2, successful: true)
      Factory(:backer, project: project, value: project.goal, confirmed: true)
    end

  end

  scenario "When I visit explore projects, it should show the correct projects" do

    categories = Category.with_projects.order(:name).all
    recommended = Project.visible.not_expired.recommended.order('expires_at').all
    expiring = Project.visible.expiring.limit(16).order('expires_at').all
    recent = Project.visible.recent.not_expired.limit(16).order('created_at DESC').all
    successful = Project.visible.successful.order('expires_at DESC').all
    search = Project.visible.where("name ILIKE '%eird%'").order('created_at DESC').all

    visit homepage
    verify_translations

    click_on "Explorar encontros"
    verify_translations

    within 'head title' do
      page.should have_content("Explorar encontros · #{I18n.t('site.name')}")
    end

    quick_list = find("#explore_quick").all("li")
    quick_list[0].text.should == "Nossos destaques"
    quick_list[1].text.should == "Última chamada"
    quick_list[2].text.should == "Saindo do forno"
    quick_list[3].text.should == "Confirmados"

    categories_list = find("#explore_categories").all("li")
    categories_list.each_index do |index|
      categories_list[index].text.should == categories[index].name
    end

    # It should be already on recommended projects
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{recommended[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Nossos destaques"

    # Now I go to expiring projects
    within ".sidebar .content" do
      click_on "Última chamada"
    end
    verify_translations
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{expiring[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Última chamada"

    # Now I go to recent projects
    within ".sidebar .content" do
      click_on "Saindo do forno"
    end
    verify_translations
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{recent[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Saindo do forno"

    # Now I go to successful projects
    within ".sidebar .content" do
      click_on "Confirmados"
    end
    verify_translations
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{successful[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Confirmados"

    # Now I go to recommended projects again
    within ".sidebar .content" do
      click_on "Nossos destaques"
    end
    verify_translations
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{recommended[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Nossos destaques"

    # Now I search for "eird"
    within "#header .search" do
      fill_in "search", with: "eird"
    end
    sleep 2
    verify_translations
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{search[index].to_param}/)
      end
    end
    page.should have_no_css('.sidebar .content .selected')

    # Now I search for "empty search"
    within "#header .search" do
      fill_in "search", with: "empty search"
    end
    sleep 2
    verify_translations
    within "#explore_results" do
      all(".project_box").empty?.should == true
      page.should have_content("Desculpe, não encontramos nenhum encontro com o texto que você procurou. Você pode tentar outras palavras?")
    end
    page.should have_no_css('.sidebar .content .selected')

    # Now I go through every category
    categories.each do |category|
      projects = Project.visible.where(category_id: category.id).order('created_at DESC').all
      within ".list_categories" do
        click_on category.name
      end
      within "#explore_results" do
        list = all(".project_box")
        list.each_index do |index|
          list[index].find("a")[:href].should match(/\/projects\/#{projects[index].to_param}/)
        end
      end
      find('.list_categories .selected').text.should == category.name
    end

    visit "/pt/explore#recommended"
    verify_translations

    projects = Project.visible.not_expired.recommended.order('expires_at').all
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{projects[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Nossos destaques"

    visit "/pt/explore#expiring"
    verify_translations

    projects = Project.visible.expiring.limit(16).order('expires_at').all
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{projects[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Última chamada"

    visit "/pt/explore#recent"
    verify_translations

    projects = Project.visible.recent.limit(16).order('created_at DESC').all
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{projects[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Saindo do forno"

    visit "/pt/explore#successful"
    verify_translations

    projects = Project.visible.successful.order('expires_at DESC').all
    within "#explore_results" do
      list = all(".project_box")
      list.each_index do |index|
        list[index].find("a")[:href].should match(/\/projects\/#{projects[index].to_param}/)
      end
    end
    find('.sidebar .content .selected').text.should == "Confirmados"

  end

end
