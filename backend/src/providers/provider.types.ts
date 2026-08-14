export type ProviderName =
  | 'PROVIDER_A'
  | 'PROVIDER_B'
  | 'PROVIDER_C';

export interface NormalizedProviderResult {
  provider: ProviderName;
  externalId: string;
  status: 'SUCCESS' | 'REJECTED';
  score: number | null;
  message: string | null;
}