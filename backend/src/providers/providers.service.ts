import {
  Injectable,
  RequestTimeoutException,
} from '@nestjs/common';

import {
  NormalizedProviderResult,
} from './provider.types';

@Injectable()
export class ProvidersService {
  // ============================================================
  // PROVIDER A
  //
  // Nested JSON response
  // ============================================================

  async callProviderA(
    packageId: string,
  ): Promise<NormalizedProviderResult[]> {
    await this.delay(500);

    const rawResponse = {
      transaction: {
        reference: `A-${packageId}`,
        result: {
          decision: 'approved',
          confidence: 91,
          description:
            'Provider A completed successfully',
        },
      },
    };

    return [
      {
        provider: 'PROVIDER_A',

        externalId:
          rawResponse.transaction.reference,

        status:
          rawResponse.transaction.result.decision ===
          'approved'
            ? 'SUCCESS'
            : 'REJECTED',

        score:
          rawResponse.transaction.result.confidence,

        message:
          rawResponse.transaction.result.description,
      },
    ];
  }

  // ============================================================
  // PROVIDER B
  //
  // Flat response.
  // First attempt deliberately times out.
  // Second attempt succeeds.
  //
  // This gives us a predictable failure/retry demonstration
  // instead of random behavior.
  // ============================================================

  async callProviderB(
    packageId: string,
  ): Promise<NormalizedProviderResult[]> {
    const maxAttempts = 2;

    for (
      let attempt = 1;
      attempt <= maxAttempts;
      attempt++
    ) {
      try {
        return await this.executeProviderB(
          packageId,
          attempt,
        );
      } catch (error) {
        console.warn(
          `Provider B attempt ${attempt} failed`,
        );

        if (attempt === maxAttempts) {
          throw error;
        }

        await this.delay(500);
      }
    }

    throw new RequestTimeoutException(
      'Provider B failed',
    );
  }

  private async executeProviderB(
    packageId: string,
    attempt: number,
  ): Promise<NormalizedProviderResult[]> {
    // Simulate timeout on first attempt.
    if (attempt === 1) {
      await this.delay(1200);

      throw new RequestTimeoutException(
        'Provider B timed out',
      );
    }

    await this.delay(400);

    const rawResponse = {
      id: `B-${packageId}`,
      ok: true,
      rating: 78,
      text:
        'Provider B succeeded after retry',
    };

    return [
      {
        provider:
          'PROVIDER_B',

        externalId:
          rawResponse.id,

        status:
          rawResponse.ok
            ? 'SUCCESS'
            : 'REJECTED',

        score:
          rawResponse.rating,

        message:
          rawResponse.text,
      },
    ];
  }

  // ============================================================
  // PROVIDER C
  //
  // Inconsistent field names + duplicated results.
  // ============================================================

  async callProviderC(
    packageId: string,
  ): Promise<NormalizedProviderResult[]> {
    await this.delay(600);

    const rawResponse = [
      {
        reference_id:
          `C-${packageId}-1`,

        result_status:
          'OK',

        confidence_score:
          87,

        description:
          'Provider C result',
      },

      // Deliberate duplicate
      {
        ref:
          `C-${packageId}-1`,

        state:
          'success',

        score:
          87,

        msg:
          'Provider C duplicate result',
      },

      {
        ref:
          `C-${packageId}-2`,

        state:
          'success',

        score:
          82,

        msg:
          'Provider C secondary result',
      },
    ];

    const normalized =
        rawResponse.map(
      (item: any) => {
        const externalId =
            item.reference_id ??
            item.ref ??
            item.reference;

        const rawStatus =
            item.result_status ??
            item.state ??
            item.status;

        const score =
            item.confidence_score ??
            item.score ??
            null;

        const message =
            item.description ??
            item.msg ??
            item.message ??
            null;

        return {
          provider:
            'PROVIDER_C' as const,

          externalId:
            String(externalId),

          status:
            this.isSuccessStatus(
              rawStatus,
            )
              ? ('SUCCESS' as const)
              : ('REJECTED' as const),

          score:
            score == null
              ? null
              : Number(score),

          message:
            message == null
              ? null
              : String(message),
        };
      },
    );

    // ----------------------------------------------------------
    // DUPLICATE SUPPRESSION
    // ----------------------------------------------------------

    const unique =
        new Map<
          string,
          NormalizedProviderResult
        >();

    for (const result of normalized) {
      if (
        !unique.has(
          result.externalId,
        )
      ) {
        unique.set(
          result.externalId,
          result,
        );
      }
    }

    return [
      ...unique.values(),
    ];
  }

  // ============================================================
  // CALL ALL PROVIDERS
  // ============================================================

  async processPackage(
    packageId: string,
  ): Promise<NormalizedProviderResult[]> {
    const [
      providerA,
      providerB,
      providerC,
    ] = await Promise.all([
      this.callProviderA(
        packageId,
      ),

      this.callProviderB(
        packageId,
      ),

      this.callProviderC(
        packageId,
      ),
    ]);

    return [
      ...providerA,
      ...providerB,
      ...providerC,
    ];
  }

  private isSuccessStatus(
    value: unknown,
  ) {
    const normalized =
        String(value)
          .toLowerCase();

    return [
      'ok',
      'success',
      'approved',
      'completed',
    ].includes(
      normalized,
    );
  }

  private delay(
    milliseconds: number,
  ) {
    return new Promise<void>(
      (resolve) =>
        setTimeout(
          resolve,
          milliseconds,
        ),
    );
  }
}