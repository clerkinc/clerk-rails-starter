window.startClerk = async () => {
  const Clerk = window.Clerk;

  try {
    // Load Clerk environment & session if available
    await Clerk.load({ authVersion: 2});

    if (Clerk.user) {
      // Mount user button component
      const userButtonEl = document.getElementById('user-button');
      Clerk.mountUserButton(userButtonEl);
    }
  } catch (err) {
    console.error('Clerk: ', err);
  }
}
