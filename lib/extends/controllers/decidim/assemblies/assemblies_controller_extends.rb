module AssembliesControllerExtends
  def current_assemblies_settings
    @current_assemblies_settings ||= Decidim::AssembliesSetting.find_by(decidim_organization_id: current_organization.id)
  end
end

Decidim::Assemblies::AssembliesController.class_eval do
  prepend(AssembliesControllerExtends)
end

