use eyre::{Context, ContextCompat, eyre};

#[tokio::main]
async fn main() -> eyre::Result<()> {
    let network = unsafe { foundationdb::boot() };

    let mut args = std::env::args();

    args.next().wrap_err("Unable to get exec name")?;
    let cluster_path = args.next().wrap_err("Unable to get cluster path")?;

    run(&cluster_path).await?;

    drop(network);
    Ok(())
}

async fn run(cluster_path: &str) -> eyre::Result<()> {
    let db = foundationdb::Database::from_path(cluster_path)
        .wrap_err(eyre!("Unable to create database from {cluster_path}"))?;

    let now = std::time::SystemTime::now()
        .duration_since(std::time::SystemTime::UNIX_EPOCH)?
        .as_secs();
    db.run(|trx, _| async move {
        trx.set(
            format!("hello-{now}").as_bytes(),
            format!("world-{now}").as_bytes(),
        );
        Ok(())
    })
    .await?;
    println!("I was here");

    Ok(())
}
