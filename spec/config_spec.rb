


RSpec.describe Dockerun::Config do

  it 'load empty config' do
    Dockerun::Config.remove
    conf = Dockerun::Config.from_storage
    expect(conf.isConfigFileAvail?).to be false

    image_name = "testimgname"
    conf.add_container(image_name,"testCont")
    conf.add_mount_to_container(image_name, "testCont",{ "$PWD" => "/lib" })

    conf.to_storage

    conf2 = Dockerun::Config.from_storage
    imgNm = conf2.image_names.first
    expect(conf2.container_names(imgNm).first == conf.container_names(image_name).first).to be true
    contConfig = conf.container_configs(image_name,conf.container_names(image_name).first)
    contConfig2 = conf2.container_configs(imgNm, conf2.container_names(imgNm).first)
    expect(contConfig == contConfig2).to be true

    conf.add_mount_to_container(imgNm, "newCont", { "$PWD" => "/lib2" })
    expect(conf.container_names(imgNm).last == "newCont").to be true
    expect(conf.container_names(imgNm).length == 2).to be true

  end

end
