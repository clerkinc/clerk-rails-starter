window.startClerk = async () => {
  const Clerk = window.Clerk;

  try {
    // Load Clerk environment & session if available
    await Clerk.load({authVersion: 1});

    function mountUserButton() {
      if (Clerk.user && !document.getElementById('user-button').hasChildNodes()) {
        const userButtonEl = document.getElementById('user-button');
        Clerk.mountUserButton(userButtonEl);
      }
    }

    document.addEventListener("turbolinks:load", mountUserButton);

    mountUserButton();
  } catch (err) {
    console.error('Clerk: ', err);
  }
}
