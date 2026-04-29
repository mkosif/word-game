import { cryptoFramework } from '@kit.CryptoArchitectureKit'

export function secureRandomNumber(): number {
  try {
    const rand = cryptoFramework.createRandom()
    const randData = rand.generateRandomSync(8)
    const bytes = randData.data
    let value = BigInt(0)
    for (let i = 0; i < 8; i++) {
      value = (value << BigInt(8)) | BigInt(bytes[i])
    }
    return Number(value >> BigInt(11)) / Number(BigInt(1) << BigInt(53))
  } catch (error) {
    console.error(`[SecureRandom] random generation failed: ${JSON.stringify(error)}`)
    return 0
  }
}
