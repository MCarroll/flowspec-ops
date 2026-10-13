defmodule FlowspecOpsWeb.Router do
  use FlowspecOpsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FlowspecOpsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FlowspecOpsWeb do
    pipe_through :browser
    live "/", ClientsLive, :index
    live "/clients", ClientsLive, :index
    live "/factory/projects", Factory.ProjectsLive, :index
    live "/factory/projects/:id", Factory.ShowLive, :show
    get "/factory/projects/:factory_id/nodes/:node_id/pencil", PencilController, :show
    get "/factory/projects/:factory_id/storage-groups/:group/pencil", PencilController, :storage_group
    live "/factory/templates", Factory.TemplatesLive, :index
    live "/factory/part-specs", Factory.PartSpecsLive, :index
    live "/toc", TOC.TocLive, :index
    live "/toc/:id", TOC.TocShowLive, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", FlowspecOpsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:flowspec_ops, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FlowspecOpsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
