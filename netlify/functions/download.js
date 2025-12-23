export async function handler(event) {
  const filename = event.path.replace("/download/", "");
  const owner = "ZodiacTeamOS";
  const repo = "Add-MicrosoftStore-LTSC";
  const releaseTag = "the_bun";

  if (!filename) {
    return { statusCode: 400, body: "Missing filename" };
  }

  const headers = {
    Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
    Accept: "application/vnd.github+json",
  };

  // 1) Get release info
  const releaseRes = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/releases/tags/${releaseTag}`,
    { headers }
  );

  if (!releaseRes.ok) {
    return { statusCode: 500, body: "Failed to fetch release" };
  }

  const release = await releaseRes.json();

  // 2) Find asset by name
  const asset = release.assets.find(a => a.name === filename);

  if (!asset) {
    return { statusCode: 404, body: "File not found" };
  }

  // 3) Download asset by ID (PRIVATE-SAFE)
  const downloadRes = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/releases/assets/${asset.id}`,
    {
      headers: {
        Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
        Accept: "application/octet-stream",
      },
    }
  );

  const buffer = await downloadRes.arrayBuffer();

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/octet-stream",
      "Content-Disposition": `attachment; filename="${filename}"`,
    },
    body: Buffer.from(buffer).toString("base64"),
    isBase64Encoded: true,
  };
}
