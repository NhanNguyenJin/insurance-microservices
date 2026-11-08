using NHibernate.Cfg;
using NHibernate.Dialect;
using NHibernate.Driver;
using NHibernate.Connection;
using NHibernate.Bytecode;
using NHibernate.Tool.hbm2ddl;

var cn = "User ID=lab_user;Password=lab_pass;Database=lab_netmicro_policy;Host=localhost;Port=5432";
var cfg = new Configuration();
cfg.DataBaseIntegration(db =>
{
    db.Dialect<PostgreSQL83Dialect>();
    db.Driver<NpgsqlDriver>();
    db.ConnectionProvider<DriverConnectionProvider>();
    db.IsolationLevel = System.Data.IsolationLevel.ReadCommitted;
    db.ConnectionString = cn;
});
cfg.Proxy(p => p.ProxyFactoryFactory<StaticProxyFactoryFactory>());
cfg.Cache(c => c.UseQueryCache = false);
cfg.AddAssembly(typeof(PolicyService.DataAccess.NHibernate.NHibernateInstaller).Assembly);
new SchemaExport(cfg).SetOutputFile(@"D:\nhan\InsuranceSolution\MigrationRunner\schema.sql").Create(false, true);
Console.WriteLine("SCHEMA-UPDATED");
