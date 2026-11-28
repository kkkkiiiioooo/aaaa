const { chromium } = require('playwright');

(async () => {
  const b = await chromium.connectOverCDP(process.env.WS_ENDPOINT);
  const ctx = b.contexts()[0] || await b.newContext();
  const p = ctx.pages()[0] || await ctx.newPage();
  await p.goto('https://example.com');
  console.log(await p.title());
  await b.close();
})();
