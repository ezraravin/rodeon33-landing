<script>
  // Define props
    let {title = "", subtitle = "", command = ""} = $props();

  let isCopied = $state(false);


  // Function to copy the command to the clipboard
  function copyCommand() {
    navigator.clipboard.writeText(command).then(() => {
    isCopied = true; // Update state to "copied"
          setTimeout(() => (isCopied = false), 2000);
    }).catch(() => {
      alert("Failed to copy command.");
    });
  }
</script>

<div class="max-w-2xl mx-auto bg-white p-6 rounded-lg shadow-md">
  <h1 class="text-2xl font-bold mb-4">{title}</h1>
  <p class="mb-4">{subtitle}</p>
  <div class="flex items-center bg-gray-200 p-3 rounded-lg">
    <code class="flex-1 font-mono text-sm">
      {command}
    </code>
    <button
      onclick={copyCommand}
      class="ml-4 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none flex items-center"
    >
      {#if isCopied}
        <i class="fas fa-check"></i>
      {:else}
        <i class="fas fa-clone"></i>
      {/if}
    </button>
  </div>
</div>
