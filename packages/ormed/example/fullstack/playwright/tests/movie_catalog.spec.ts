import { expect, test } from '@playwright/test';
// @ts-ignore
async function createMovie(page, title: string) {
  await page.goto('/movies/new');
  await page.fill('input[name="title"]', title);
  await page.fill('input[name="releaseYear"]', '2024');
  await page.selectOption('select[name="genreId"]', { label: 'Drama' });
  await page.fill(
    'textarea[name="summary"]',
    'A lighthouse keeper rebuilds a lost archive.',
  );
  await page.click('button[type="submit"]');
  await expect(page.getByRole('heading', { name: title })).toBeVisible();
}
// @ts-ignore
test('catalog page renders', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Movie Catalog' })).toBeVisible();
  await expect(page.getByText('City of Amber')).toBeVisible();
});
// @ts-ignore
test('can add a movie from the form', async ({ page }) => {
  await createMovie(page, 'Shoreline Echoes');
});

// @ts-ignore
test('genre detail shows catalog entries', async ({ page }) => {
  await page.goto('/genres/1');
  await expect(page.getByRole('heading', { name: 'Drama' })).toBeVisible();
  await expect(page.getByText('Ashes in Winter')).toBeVisible();
});

// @ts-ignore
test('can edit a movie summary', async ({ page }) => {
  const title = `Edit Trail ${Date.now()}`;
  await createMovie(page, title);

  await page.click('a:has-text("Edit")');
  await page.fill('textarea[name="summary"]', 'A revised logline for the archive.');
  await page.click('button[type="submit"]');

  await expect(page.getByText('A revised logline for the archive.')).toBeVisible();
});

// @ts-ignore
test('can delete a movie from the UI', async ({ page }) => {
  const title = `Delete Trail ${Date.now()}`;
  await createMovie(page, title);

  await page.click('a:has-text("Delete")');
  await expect(page.getByRole('heading', { name: `Delete ${title}?` })).toBeVisible();
  await page.click('button:has-text("Yes, delete")');

  await expect(page.getByRole('heading', { name: 'Movie Catalog' })).toBeVisible();
  await expect(page.getByText(title)).toHaveCount(0);
});
