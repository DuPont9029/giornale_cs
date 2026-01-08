# Giornale CS - Decentralized Newspaper

Piattaforma di giornalismo decentralizzato su Ethereum. Il possesso dell'NFT (Soulbound) garantisce diritti di governance e accesso ai contenuti.
Tutto il sistema è progettato per essere **unstoppable**: niente backend, solo blockchain e frontend statico.

## Come funziona
L'intera applicazione vive in `index.html`.
- **Frontend**: HTML5, CSS3, Vanilla JS (Single Page Application).
- **3D**: Three.js per la visualizzazione interattiva.
- **Blockchain**: Ethers.js per interagire con lo smart contract.
- **PDF**: Generazione locale del giornale tramite jsPDF (impaginazione automatica a colonne).

cosa importante: alcune volte metamask si bugga, fai il logout e login di nuovo. 

## Funzionalità principali
- **Minting & Gifting**: Sottoscrizione al giornale (coniazione NFT) per sé o per altri wallet.
- **Lettura**: Visualizzazione e download PDF dell'edizione corrente con layout tipografico.
- **Governance On-Chain**: I possessori dell'NFT propongono e votano le modifiche editoriali.
- **Ottimizzazione Gas**: Sistema di riutilizzo degli slot proposta scaduti per ridurre i costi di transazione.

## Setup veloce
Non servono build tools complessi o `npm install`.

1. Clona la repo.
2. Avvia un server locale nella cartella (necessario per caricare le texture/risorse correttamente):
   ```bash
   # Esempio con Python
   python3 -m http.server
   # Oppure usa l'estensione "Live Server" di VS Code
   ```
3. Apri il browser su `localhost` e connetti MetaMask.

## Indirizzi Smart Contract
Il frontend rileva automaticamente la rete selezionata su MetaMask e si collega al contratto corretto:

| Rete | Indirizzo Contratto |
|------|-------------------|
| **Ethereum Mainnet** | `0x6462A6c527373a2EE3F1415503ae4BAB5acd5618` |
| **Sepolia Testnet** | `0xEd9EfF0E06DB8233EDCBEedb3bCee804A70A4BB7` |


## aggiungerò in seguito tutto il Next.js (cosa che non voglio fare più di tanto perchè sono weeks che patcho le vulns di vercel) per rendere tutto questo in qualche modo manutenibile anche se so benissimo che sarò l'unico a toccare questa repo