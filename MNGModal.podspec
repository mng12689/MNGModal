Pod::Spec.new do |s|
  s.name = 'MNGModal'
  s.version = '0.1'
  s.license = { :type => 'MIT' }
  s.homepage = 'https://github.com/mng12689/MNGModal'
  s.authors = { 'Michael Ng' => 'mng12689@gmail.com' }
  s.summary = 'Category on UIViewController that allows for more precise management of modal view controller behavior'
  s.source = { :git => 'git@github.com:mng12689/MNGModal.git', :tag => 'v0.1' }
  s.source_files = 'MNGModal/UIViewController+CustomModals.*', 'MNGModal/MNGModalManager.*'
  s.requires_arc = true 
end