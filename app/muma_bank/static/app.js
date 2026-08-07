const accountGrid = document.querySelector("#account-grid");
const totalBalance = document.querySelector("#total-balance");
const sourceSelect = document.querySelector("#source-account");
const destinationSelect = document.querySelector("#destination-account");
const transferForm = document.querySelector("#transfer-form");
const formStatus = document.querySelector("#form-status");
const swapButton = document.querySelector("#swap-accounts");
const toast = document.querySelector("#toast");
const toastMessage = document.querySelector("#toast-message");

const currency = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  minimumFractionDigits: 2,
});

let accounts = [];
let toastTimer;

function formatBalance(value) {
  return currency.format(Number(value));
}

function makeElement(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
}

function createAccountCard(account, index) {
  const card = makeElement("article", "account-card");
  const top = makeElement("div", "account-top");
  const accountIndex = makeElement("span", "account-index", String(index + 1).padStart(2, "0"));
  const accountCurrency = makeElement("span", "account-currency", account.currency);
  const balance = makeElement("strong", "account-balance", formatBalance(account.balance));
  const meta = makeElement("div", "account-meta");
  const owner = makeElement("span", "account-owner", account.owner);
  const identifier = makeElement("span", "account-id", account.account_id);

  top.append(accountIndex, accountCurrency);
  meta.append(owner, identifier);
  card.append(top, balance, meta);
  return card;
}

function createAccountOption(account) {
  const option = document.createElement("option");
  option.value = account.account_id;
  option.textContent = `${account.owner} · ${formatBalance(account.balance)}`;
  return option;
}

function renderAccounts() {
  accountGrid.replaceChildren(...accounts.map(createAccountCard));
  accountGrid.setAttribute("aria-busy", "false");

  const total = accounts.reduce((sum, account) => sum + Number(account.balance), 0);
  totalBalance.textContent = currency.format(total);

  const sourceValue = sourceSelect.value;
  const destinationValue = destinationSelect.value;
  sourceSelect.length = 1;
  destinationSelect.length = 1;
  accounts.forEach((account) => {
    sourceSelect.append(createAccountOption(account));
    destinationSelect.append(createAccountOption(account));
  });
  sourceSelect.value = sourceValue;
  destinationSelect.value = destinationValue;
}

function showLoadError(message) {
  accountGrid.setAttribute("aria-busy", "false");
  accountGrid.replaceChildren(makeElement("p", "load-error", message));
  totalBalance.textContent = "Unavailable";
}

async function loadAccounts() {
  try {
    const response = await fetch("/api/v1/accounts", { headers: { Accept: "application/json" } });
    if (!response.ok) throw new Error("Accounts could not be loaded.");
    const data = await response.json();
    accounts = data.accounts;
    renderAccounts();
  } catch (error) {
    showLoadError(error.message);
  }
}

function showToast(message) {
  window.clearTimeout(toastTimer);
  toastMessage.textContent = message;
  toast.classList.add("visible");
  toast.setAttribute("aria-hidden", "false");
  toastTimer = window.setTimeout(() => {
    toast.classList.remove("visible");
    toast.setAttribute("aria-hidden", "true");
  }, 4500);
}

async function submitTransfer(event) {
  event.preventDefault();
  formStatus.textContent = "";

  const submitButton = transferForm.querySelector("button[type='submit']");
  const formData = new FormData(transferForm);
  const payload = Object.fromEntries(formData.entries());
  submitButton.disabled = true;
  submitButton.querySelector("span").textContent = "Processing…";

  try {
    const response = await fetch("/api/v1/transfers", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error?.message || "Transfer could not be completed.");

    showToast(`${formatBalance(data.transfer.amount)} moved successfully.`);
    transferForm.reset();
    await loadAccounts();
  } catch (error) {
    formStatus.textContent = error.message;
  } finally {
    submitButton.disabled = false;
    submitButton.querySelector("span").textContent = "Complete transfer";
  }
}

function swapAccounts() {
  const source = sourceSelect.value;
  sourceSelect.value = destinationSelect.value;
  destinationSelect.value = source;
}

transferForm.addEventListener("submit", submitTransfer);
swapButton.addEventListener("click", swapAccounts);
loadAccounts();
