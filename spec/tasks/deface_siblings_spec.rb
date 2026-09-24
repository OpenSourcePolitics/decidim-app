# frozen_string_literal: true

require "spec_helper"
require "rake"

describe "deface:copy_non_html_siblings" do
  let(:task) { Rake::Task["deface:copy_non_html_siblings"] }
  let(:root) { Pathname.new(Dir.mktmpdir) }
  let(:compiled_views) { root.join("app/compiled_views") }
  let(:engine_views) { Pathname.new(Dir.mktmpdir) }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("deface:copy_non_html_siblings")
    # :environment est un prérequis de la tâche ; Rake ne le rejoue pas une fois
    # invoqué, donc l'appeler ici ne coûte rien à partir du deuxième exemple.
    Rake::Task["environment"].invoke
    task.reenable
    allow(Rails).to receive(:root).and_return(root)
  end

  after do
    FileUtils.remove_entry(root, true)
    FileUtils.remove_entry(engine_views, true)
  end

  # Écrit une vue compilée par Deface (toujours en .html.erb).
  def compiled(virtual_path, content = "<p>compiled</p>")
    path = compiled_views.join("#{virtual_path}.html.erb")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    path
  end

  # Écrit un template dans le faux view path "moteur".
  def engine_template(virtual_path, format, content)
    path = engine_views.join("#{virtual_path}.#{format}.erb")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    path
  end

  def run_task
    original = $stdout
    $stdout = StringIO.new
    task.invoke
    $stdout.string
  ensure
    $stdout = original
  end

  context "with a stubbed view path" do
    before do
      allow(ActionController::Base).to receive(:view_paths).and_return(ActionView::PathSet.new([engine_views.to_s]))
    end

    it "copies the .js.erb sibling next to the compiled view" do
      compiled("foo/bar/index")
      engine_template("foo/bar/index", :html, "<p>engine</p>")
      engine_template("foo/bar/index", :js, "var x = 1;")

      output = run_task

      expect(compiled_views.join("foo/bar/index.js.erb")).to exist
      expect(compiled_views.join("foo/bar/index.js.erb").read).to eq("var x = 1;")
      expect(output).to include("1 template(s) copié(s)")
    end

    # La résolution lève ActionView::MissingTemplate, que la tâche rattrape.
    it "does not copy anything when no sibling exists" do
      compiled("foo/bar/index")
      engine_template("foo/bar/index", :html, "<p>engine</p>")

      output = run_task

      expect(compiled_views.join("foo/bar/index.js.erb")).not_to exist
      expect(output).to include("0 template(s) copié(s)")
    end

    # Couvre le filet de sécurité "next unless template.format == format", qui
    # nous protège d'une résolution renvoyant du html pour une demande de js.
    it "never copies an html template under a .js.erb name" do
      compiled("foo/bar/index")
      engine_template("foo/bar/index", :html, "<p>engine</p>")

      html_template = ActionView::LookupContext.new(ActionView::PathSet.new([engine_views.to_s])).find_template("foo/bar/index")
      expect(html_template.format).to eq(:html)
      allow(ActionView::LookupContext).to receive(:new)
        .and_return(instance_double(ActionView::LookupContext, find_template: html_template))

      run_task

      expect(compiled_views.join("foo/bar/index.js.erb")).not_to exist
    end

    it "copies .json.erb siblings too" do
      compiled("foo/bar/index")
      engine_template("foo/bar/index", :json, '{ "ok": true }')

      run_task

      expect(compiled_views.join("foo/bar/index.json.erb").read).to eq('{ "ok": true }')
    end

    it "handles partials" do
      compiled("foo/bar/_widget")
      engine_template("foo/bar/_widget", :js, "var widget = 1;")

      run_task

      expect(compiled_views.join("foo/bar/_widget.js.erb").read).to eq("var widget = 1;")
    end

    it "leaves the compiled HTML untouched" do
      compiled("foo/bar/index", "<p>compiled</p>")
      engine_template("foo/bar/index", :js, "var x = 1;")

      run_task

      expect(compiled_views.join("foo/bar/index.html.erb").read).to eq("<p>compiled</p>")
    end

    it "does nothing when app/compiled_views is absent" do
      expect { run_task }.not_to raise_error
      expect(compiled_views).not_to exist
    end
  end

  # Garde-fou sur la régression réelle : l'index des propositions est rendu en
  # HTML au lieu de JS dès que sa vue compilée n'a pas de frère .js.erb, parce
  # que app/compiled_views est placé en tête de la chaîne de résolution.
  context "with the real view paths" do
    let(:virtual_path) { "decidim/proposals/proposals/index" }

    it "copies the proposals index JS template" do
      compiled(virtual_path)

      run_task

      copied = compiled_views.join("#{virtual_path}.js.erb")
      expect(copied).to exist
      expect(copied.read).to include("$proposals.html(")
    end

    it "resolves a JS request to the copied template rather than the compiled HTML" do
      compiled(virtual_path)
      run_task

      lookup = ActionView::LookupContext.new(ActionView::PathSet.new([compiled_views.to_s]))
      lookup.formats = [:js]

      expect(lookup.find_template(virtual_path).format).to eq(:js)
    end
  end

  describe "the deface:precompile hook" do
    it "runs the copy at the end of deface:precompile" do
      expect(task).to receive(:invoke)

      # Rake::Task#enhance ajoute le bloc en dernière action.
      Rake::Task["deface:precompile"].actions.last.call
    end
  end
end
