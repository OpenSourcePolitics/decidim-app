# frozen_string_literal: true

# Deface::Precompiler n'écrit jamais que des "<virtual_path>.html.erb" dans
# app/compiled_views. Or ce répertoire est placé en tête de la chaîne de
# résolution des vues (initializer "deface.precompile.inject_views"), et
# ActionView::PathSet#_find_all retient le premier view path qui répond, quel
# que soit le format. Une requête au format js étant résolue avec les formats
# [:js, :html], le template HTML compilé l'intercepte et les "<name>.js.erb"
# des moteurs deviennent inatteignables.
#
# Cette tâche recopie ces templates frères à côté de leur homologue compilé.
# Elle est accrochée à deface:precompile (voir en bas du fichier), donc toute
# invocation de la précompilation la déclenche.
namespace :deface do
  desc "Copie dans app/compiled_views les templates non-HTML masqués par la précompilation"
  task copy_non_html_siblings: :environment do
    base = Rails.root.join("app/compiled_views")

    unless base.directory?
      puts "[deface:copy_non_html_siblings] app/compiled_views absent, rien à faire"
      next
    end

    sources = ActionController::Base.view_paths.reject { |resolver| resolver.to_s.include?("compiled_views") }
    copied = 0

    Dir.glob(base.join("**/*.html.erb")).each do |compiled|
      virtual_path = compiled.delete_prefix("#{base}/").delete_suffix(".html.erb")
      prefix, _slash, name = virtual_path.rpartition("/")
      partial = name.start_with?("_")

      [:js, :json].each do |format|
        lookup = ActionView::LookupContext.new(sources, formats: [format])

        template = begin
          lookup.find_template(partial ? name.delete_prefix("_") : name, [prefix], partial)
        rescue ActionView::MissingTemplate
          next
        end

        # Filet de sécurité. Le fallback html de Rails pour les requêtes js
        # (formats [:js] -> [:js, :html]) ne s'applique pas ici : il vit dans le
        # setter LookupContext#formats=, que le constructeur ci-dessus contourne
        # en écrivant @details[:formats] directement. On refuse quand même de
        # recopier un template html sous un nom en .js.erb, au cas où.
        next unless template.format == format

        destination = base.join("#{virtual_path}.#{format}.erb")
        FileUtils.cp(template.identifier, destination)
        copied += 1
        puts "[deface:copy_non_html_siblings] #{template.identifier} -> #{destination}"
      end
    end

    puts "[deface:copy_non_html_siblings] #{copied} template(s) copié(s)"
  end
end

# Post-traitement inséparable de la précompilation
Rake::Task["deface:precompile"].enhance do
  Rake::Task["deface:copy_non_html_siblings"].invoke
end
