export async function handler(event) {
  const filename = event.path.replace("/download/", "");


  if (!filename) {
    return { statusCode: 400, body: "Missing filename" };
  }

  const releaseTag = "the_bun";
  const url = `https://github.com/ZodiacTeamOS/Add-MicrosoftStore-LTSC/releases/download/${releaseTag}/${filename}`;

  const res = await fetch(url, {
    headers: {
      Authorization: `token ${process.env.GITHUB_TOKEN}`,
      Accept: "application/octet-stream",
    },
  });

  if (!res.ok) {
    return {
      statusCode: res.status,
      body: "File not found",
    };
  }

  const buffer = await res.arrayBuffer();

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
