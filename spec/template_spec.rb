

RSpec.describe "Templating engine" do

  it 'Load available templates' do
    
    eng = Dockerun::Template::TemplateEngine
    avail = eng.available_templates
    expect(avail.is_a?(Array)).to be true
    expect(avail.include?("general")).to be true

  end

end
